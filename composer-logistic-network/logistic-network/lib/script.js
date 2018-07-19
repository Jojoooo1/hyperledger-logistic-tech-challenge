/**
 * Create transportUnit
 * @param {org.logistic.network.CreateTransportUnit} tx
 * @transaction
 */

 async function CreateTransportUnit(tx) {

  // Check status
  // const status = tx.status 
  // if (status <= 1 || status >= 100) {
  //   throw Error('Invalid status number')
  // }

  // Put functions factory in const factory 
  const factory = getFactory();
  // Set namespace 
  const namespace = 'org.logistic.network';

  // Get the Participant
  const shipper = tx.shipper; 
  const transporter = tx.transporter;
  const insurance = tx.insurance;
  const logisticOperator = tx.logistic_operator;
  // const current_owner = getCurrentParticipant() // (allow $type:"NetworkAdmin")

    // Check if Participant exist
    const shipperRegistry = await getParticipantRegistry(namespace + ".Shipper");
    const shipperExist = await shipperRegistry.exists(shipper.name);
    const transporterRegistry = await getParticipantRegistry(namespace + ".Transporter");
    const transporterExist = await transporterRegistry.exists(transporter.name);
    const insuranceRegistry = await getParticipantRegistry(namespace + ".Insurance");
    const insuranceExist = await insuranceRegistry.exists(insurance.name);
    const logisticOperatorRegistry = await getParticipantRegistry(namespace + ".LogisticOperator");
    const logisticOperatorExist = await logisticOperatorRegistry.exists(logisticOperator.name);

    if( !shipperExist ) {
      throw Error('Invalid Shipper name')
    } else if ( !transporterExist ) {
      throw Error('Invalid Transporter name')
    // } else if ( !insuranceExist ) {
    //  throw Error('Invalid Transporter name')
    // } else if ( !logisticOperatorExist ) {
    //  throw Error('Invalid Transporter name')
  } else {
    return getAssetRegistry(namespace + '.TransportUnit')
    .then(function (transportUnitRegistry) {
      const transport_unit_id = tx.id;
      // Create new resource
      const transportUnit = factory.newResource(namespace, 'TransportUnit', transport_unit_id);
      // Assign value from the transaction
      transportUnit.shipper = shipper;
      transportUnit.transporter = transporter
      transportUnit.insurance = insurance;
      transportUnit.logistic_operator = logisticOperator;
      transportUnit.current_owner = tx.current_owner;
      transportUnit.nfe_xml_base64 = tx.nfe_xml_base64;
      transportUnit.nfe_key = tx.nfe_key
      transportUnit.cte_xml_base64 = tx.cte_xml_base64;
      transportUnit.cte_key = tx.cte_key
      transportUnit.mdfe_xml_base64 = tx.mdfe_xml_base64;
      transportUnit.mdfe_key = tx.mdfe_key
      transportUnit.destinator = tx.destinator;
      transportUnit.weight = tx.weight;
      transportUnit.dimensions = tx.dimensions;
      transportUnit.proof_of_delivery = tx.proof_of_delivery
      transportUnit.transport_unit_status = tx.transport_unit_status 
      transportUnit.transportation_state = tx.transportation_state;
      transportUnit.other = tx.other;
      transportUnit.proof_of_theft_base64 = tx.proof_of_theft_base64;
      return transportUnitRegistry.add(transportUnit)
      .then(function (_res) {
        const transportUnitEvent = factory.newEvent(namespace, 'TransportUnitCreated');
        transportUnitEvent.transport_unit = transportUnit;
        emit(transportUnitEvent);
        return (_res)
      })
      .catch(function(error){
        console.log(error)
        return(error)
      });
    })
    .catch(function(error){
      console.log(error)
      return(error)
    });;
  }

}


/**
 * Update transportUnit
 * @param {org.logistic.network.UpdateMeasure} tx
 * @transaction
 */

 async function UpdateMeasure(tx) {

  const factory = getFactory();
  const namespace = 'org.logistic.network';

  const transportUnit = tx.transport_unit

  const TransportUnitRegistry = await getAssetRegistry(namespace + ".TransportUnit");
  const transportUnitExist = await TransportUnitRegistry.exists(transportUnit.id);

  if ( !transportUnitExist ) {
    throw Error('Transport unit does not exist')
  } 

  // Update TransportUnit
  transportUnit.weight = tx.weight
  transportUnit.dimensions = tx.dimensions

  return TransportUnitRegistry.update(transportUnit)
  .then(function(_res) {
    console.log(_res)
    const transportUnitEvent = factory.newEvent(namespace, 'MeasureUpdated');
    transportUnitEvent.transport_unit = transportUnit;
    transportUnitEvent.weight = transportUnit.weight
    transportUnitEvent.dimensions = transportUnit.dimensions
    emit(transportUnitEvent);
  })
  .catch(function(error){
    console.log(error)
    return error
  })
}

/**
 * Update status of transportUnit
 * @param {org.logistic.network.StolenTransportUnit} tx
 * @transaction
 */

 async function StolenTransportUnit(tx) {

  const factory = getFactory();
  const namespace = 'org.logistic.network';

  const transportUnit = tx.transport_unit
  // const insurance = tx.insurance
  // const InsuranceRegistry = await getAssetRegistry(namespace + ".Insurance");
  // const insuranceExist = await TransportUnitRegistry.exists(insurance.id);

  const TransportUnitRegistry = await getAssetRegistry(namespace + ".TransportUnit");
  const transportUnitExist = await TransportUnitRegistry.exists(transportUnit.id);

  if ( !transportUnitExist ) {
    throw Error('Transport unit does not exist')
  } 

  // if ( !insuranceExist ) {
  //   throw Error('Insurer does not exist')
  // } else if (getCurrentParticipant() != insurance) {
  //   throw Error('Insurer does not match')
  // }

  // Update TransportUnit
  transportUnit.transport_unit_status = tx.transport_unit_status


  return TransportUnitRegistry.update(transportUnit)
  .then(function(_res) {
    const transportUnitEventtransportUnitEvent = factory.newEvent(namespace, 'TransportUnitStolen');
    transportUnitEventtransportUnitEvent.transport_unit = transportUnit;
    transportUnitEventtransportUnitEvent.transport_unit_status = transportUnit.transport_unit_status
    emit(transportUnitEventtransportUnitEvent);
  })
  .catch(function(error){
    console.log(error)
    return error
  })
}

/**
 * Update Nfe of transportUnit
 * @param {org.logistic.network.AddNfe} tx
 * @transaction
 */

 async function AddNfe(tx) {

  const factory = getFactory();
  const namespace = 'org.logistic.network';

  const transportUnit = tx.transport_unit;
  const TransportUnitRegistry = await getAssetRegistry(namespace + ".TransportUnit");
  const transportUnitExist = await TransportUnitRegistry.exists(transportUnit.id);

  if ( !transportUnitExist ) {
    throw Error('Transport unit does not exist')
  } 

  transportUnit.nfe_xml_base64 = tx.nfe_xml_base64;
  transportUnit.nfe_key = tx.nfe_key;

  return TransportUnitRegistry.update(transportUnit)
  .then(function(_res) {
    const transportUnitEvent = factory.newEvent(namespace, 'NfeAdded');
    transportUnitEvent.transport_unit = transportUnit;
    transportUnitEvent.nfe_xml_base64 = transportUnit.nfe_xml_base64;
    transportUnitEvent.nfe_key = transportUnit.nfe_key;
    emit(transportUnitEvent);
  })
  .catch(function(error){
    console.log(error)
    return error
  })
}

/**
 * Update Cte of transportUnit
 * @param {org.logistic.network.AddCte} tx
 * @transaction
 */

 async function AddCte(tx) {

  const factory = getFactory();
  const namespace = 'org.logistic.network';

  const transportUnit = tx.transport_unit
  const TransportUnitRegistry = await getAssetRegistry(namespace + ".TransportUnit");
  const transportUnitExist = await TransportUnitRegistry.exists(transportUnit.id);

  if ( !transportUnitExist ) {
    throw Error('Transport unit does not exist')
  } 

  transportUnit.cte_xml_base64 = tx.cte_xml_base64;
  transportUnit.cte_key = tx.cte_key;

  return TransportUnitRegistry.update(transportUnit)
  .then(function(_res) {
    const transportUnitEvent = factory.newEvent(namespace, 'CteAdded');
    transportUnitEvent.transport_unit = transportUnit;
    transportUnitEvent.cte_xml_base64 = transportUnit.cte_xml_base64;
    transportUnitEvent.cte_key = transportUnit.cte_key;
    emit(transportUnitEvent);
  })
  .catch(function(error){
    console.log(error)
    return error
  })
}

/**
 * Update Mdfe of transportUnit
 * @param {org.logistic.network.AddMdfe} tx
 * @transaction
 */

 async function AddMdfe(tx) {

  const factory = getFactory();
  const namespace = 'org.logistic.network';

  const transportUnit = tx.transport_unit
  const TransportUnitRegistry = await getAssetRegistry(namespace + ".TransportUnit");
  const transportUnitExist = await TransportUnitRegistry.exists(transportUnit.id);

  if ( !transportUnitExist ) {
    throw Error('Transport unit does not exist')
  } 

  transportUnit.mdfe_xml_base64 = tx.mdfe_xml_base64;
  transportUnit.mdfe_key = tx.mdfe_key;

  return TransportUnitRegistry.update(transportUnit)
  .then(function(_res) {
    const transportUnitEvent = factory.newEvent(namespace, 'MdfeAdded');
    transportUnitEvent.transport_unit = transportUnit;
    transportUnitEvent.mdfe_xml_base64 = transportUnit.mdfe_xml_base64;
    transportUnitEvent.mdfe_key = transportUnit.mdfe_key;
    emit(transportUnitEvent);
  })
  .catch(function(error){
    console.log(error)
    return error
  })
}

/**
 * Update current owner of transportUnit
 * @param {org.logistic.network.ChangeOwnership} tx
 * @transaction
 */

 async function ChangeOwnership(tx) {

  const factory = getFactory();
  const namespace = 'org.logistic.network';

  const transportUnit = tx.transport_unit
  const TransportUnitRegistry = await getAssetRegistry(namespace + ".TransportUnit");
  const transportUnitExist = await TransportUnitRegistry.exists(transportUnit.id);

  if ( !transportUnitExist ) {
    throw Error('Transport unit does not exist')
  } 

  transportUnit.current_owner = tx.new_owner;

  return TransportUnitRegistry.update(transportUnit)
  .then(function(_res) {
    const transportUnitEvent = factory.newEvent(namespace, 'OwnershipChanged');
    transportUnitEvent.transport_unit = transportUnit;
    transportUnitEvent.new_owner = transportUnit.current_owner;
    emit(transportUnitEvent);
  })
  .catch(function(error){
    console.log(error)
    return error
  })
}

/**
 * Update current owner of transportUnit
 * @param {org.logistic.network.AddProofOfTheft} tx
 * @transaction
 */

 async function AddProofOfTheft(tx) {

  const factory = getFactory();
  const namespace = 'org.logistic.network';

  const transportUnit = tx.transport_unit
  const TransportUnitRegistry = await getAssetRegistry(namespace + ".TransportUnit");
  const transportUnitExist = await TransportUnitRegistry.exists(transportUnit.id);

  if ( !transportUnitExist ) {
    throw Error('Transport unit does not exist')
  } 

  transportUnit.proof_of_theft_base64 = tx.proof_of_theft_base64;

  return TransportUnitRegistry.update(transportUnit)
  .then(function(_res) {
    const transportUnitEvent = factory.newEvent(namespace, 'ProofOfTheftAdded');
    transportUnitEvent.transport_unit = transportUnit;
    transportUnitEvent.proof_of_theft_base64 = transportUnit.proof_of_theft_base64;
    emit(transportUnitEvent);
  })
  .catch(function(error){
    console.log(error)
    return error
  })
}